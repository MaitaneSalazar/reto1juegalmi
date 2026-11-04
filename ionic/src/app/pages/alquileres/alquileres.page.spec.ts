import { ComponentFixture, TestBed } from '@angular/core/testing';
import { AlquileresPage } from './alquileres.page';

describe('AlquileresPage', () => {
  let component: AlquileresPage;
  let fixture: ComponentFixture<AlquileresPage>;

  beforeEach(() => {
    fixture = TestBed.createComponent(AlquileresPage);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
